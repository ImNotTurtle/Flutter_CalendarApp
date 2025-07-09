import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

// Định nghĩa các kiểu dữ liệu để code được rõ ràng và an toàn
interface TodoRule {
  id: string;
  title: string;
  content: string;
  recurrence_type: 'none' | 'weekly';
  date_time?: string; // ISO 8601 string in UTC for SingleTodo
  time_of_day?: string; // HH:mm:ss for RecurringTodoRule
  days_of_week?: number[]; // 1=Monday, ..., 7=Sunday
  remind_before?: number; // Thời gian nhắc trước, tính bằng phút
}


serve(async (req) => {
  try {
    console.log("Cron job triggered: Checking for upcoming todos...");

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    // --- BƯỚC 1: LẤY TẤT CẢ CÁC "LUẬT" VÀ THỜI GIAN HIỆN TẠI BẰNG UTC ---
    const { data: allTodoRules, error: fetchError } = await supabaseAdmin
      .from('todos')
      .select('*');

    if (fetchError) throw fetchError;
    
    const nowUtc = new Date();
    const oneMinuteFromNowUtc = new Date(nowUtc.getTime() + 60 * 1000);
    const notificationsToSend: TodoRule[] = [];

    // --- BƯỚC 2: TÍNH TOÁN THỜI GIAN THÔNG BÁO CHO TỪNG "LUẬT" ---
    for (const rule of allTodoRules as TodoRule[]) {
      // Lấy thời gian nhắc trước (mặc định là 0 phút nếu không có)
      const remindBeforeMinutes = rule.remind_before || 0;
      const remindBeforeMillis = remindBeforeMinutes * 60 * 1000;

      let eventTimesUtc: Date[] = [];

      // Tính toán (các) thời điểm sự kiện sẽ diễn ra
      if (rule.recurrence_type === 'none' && rule.date_time) {
        eventTimesUtc.push(new Date(rule.date_time));
      } 
      else if (rule.recurrence_type === 'weekly' && rule.days_of_week && rule.time_of_day) {
        // Đối với luật lặp lại, chỉ cần kiểm tra cho ngày hôm nay
        const todayWeekdayUTC = nowUtc.getUTCDay() === 0 ? 7 : nowUtc.getUTCDay();

        if (rule.days_of_week.includes(todayWeekdayUTC)) {
          const [hour, minute] = rule.time_of_day.split(':').map(Number);
          const eventTimeToday = new Date(Date.UTC(
            nowUtc.getUTCFullYear(),
            nowUtc.getUTCMonth(),
            nowUtc.getUTCDate(),
            hour,
            minute
          ));
          eventTimesUtc.push(eventTimeToday);
        }
      }

      // Với mỗi thời điểm sự kiện, tính toán thời gian thông báo
      for (const eventTime of eventTimesUtc) {
        const notificationTime = new Date(eventTime.getTime() - remindBeforeMillis);

        // Kiểm tra xem thời gian thông báo có nằm trong phút tới không
        if (notificationTime >= nowUtc && notificationTime < oneMinuteFromNowUtc) {
          notificationsToSend.push(rule);
        }
      }
    }

    if (notificationsToSend.length === 0) {
      return new Response(JSON.stringify({ message: "No upcoming todos to notify." }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }
    
    // --- BƯỚC 3: GỬI EMAIL CHO CÁC SỰ KIỆN ĐÃ ĐƯỢC LỌC ---
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