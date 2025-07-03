import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

// Định nghĩa các kiểu dữ liệu để code được rõ ràng và an toàn
interface BaseTodo {
  id: string;
  title: string;
  content: string;
}

interface SingleTodo extends BaseTodo {
  date_time: string; // ISO 8601 string in UTC
}

interface RecurringTodoRule extends BaseTodo {
  time_of_day: string; // HH:mm:ss
  days_of_week: number[]; // 1=Monday, ..., 7=Sunday (theo chuẩn ISO 8601)
}

// --- HÀM HELPER CHÍNH ---
// Hàm này sẽ tạo ra các "sự kiện thực tế" (instances) từ các "luật" lặp lại
function generateRecurringInstances(rules: RecurringTodoRule[], now: Date): SingleTodo[] {
  const instances: SingleTodo[] = [];
  
  // Lấy ngày trong tuần của ngày hôm nay theo giờ UTC (Thứ 2 = 1, ..., Chủ Nhật = 7)
  const todayWeekdayUTC = now.getUTCDay() === 0 ? 7 : now.getUTCDay();

  for (const rule of rules) {
    // Kiểm tra xem hôm nay có phải là ngày lặp lại không
    if (rule.days_of_week.includes(todayWeekdayUTC)) {
      const [hour, minute] = rule.time_of_day.split(':').map(Number);
      
      // Tạo ra một DateTime hoàn chỉnh cho sự kiện của ngày hôm nay ở múi giờ UTC
      const instanceDateTime = new Date(Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        hour,
        minute
      ));

      // Tạo một object giống SingleTodo để xử lý đồng nhất
      instances.push({
        id: rule.id,
        title: rule.title,
        content: rule.content,
        date_time: instanceDateTime.toISOString(),
      });
    }
  }
  return instances;
}


serve(async (req) => {
  try {
    console.log("Cron job triggered: Checking for upcoming todos...");

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    // --- BƯỚC 1: LẤY DỮ LIỆU VÀ TÍNH TOÁN THỜI GIAN BẰNG UTC ---
    const nowUtc = new Date();
    const oneMinuteFromNowUtc = new Date(nowUtc.getTime() + 1 * 60 * 1000);

    // Lấy tất cả các "luật" từ database
    const { data: allTodoRules, error: fetchError } = await supabaseAdmin
      .from('todos')
      .select('*');

    if (fetchError) throw fetchError;

    // --- BƯỚC 2: TẠO DANH SÁCH SỰ KIỆN TỔNG HỢP ---
    const singleTodos = allTodoRules.filter(t => t.recurrence_type === 'none');
    const recurringRules = allTodoRules.filter(t => t.recurrence_type === 'weekly');
    
    // Tạo các instance cho các sự kiện lặp lại của ngày hôm nay
    const recurringInstancesToday = generateRecurringInstances(recurringRules, nowUtc);
    
    // Gom tất cả các sự kiện có thể xảy ra lại
    const allPossibleEvents: SingleTodo[] = [...singleTodos, ...recurringInstancesToday];

    // --- BƯỚC 3: LỌC RA CÁC SỰ KIỆN CẦN THÔNG BÁO TRONG PHÚT TỚI ---
    const notificationsToSend = allPossibleEvents.filter(event => {
      const eventTime = new Date(event.date_time);
      return eventTime >= nowUtc && eventTime < oneMinuteFromNowUtc;
    });

    if (notificationsToSend.length === 0) {
      return new Response(JSON.stringify({ message: "No upcoming todos to notify." }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }
    
    // --- BƯỚC 4: GỬI EMAIL ---
    for (const todo of notificationsToSend) {
      console.log(`Sending notification for: ${todo.title}`);
      
      const resendPayload = {
        from: 'Lịch Công Việc <onboarding@resend.dev>',
        to: ['quypham.spam@gmail.com'],
        subject: `Nhắc nhở: ${todo.title}`,
        html: `<p>Đã đến giờ thực hiện công việc: <strong>${todo.content}</strong></p>`,
      };

      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')!}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(resendPayload),
      });
    }

    return new Response(JSON.stringify({ message: `Sent ${notificationsToSend.length} notifications.` }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error("Function Error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});