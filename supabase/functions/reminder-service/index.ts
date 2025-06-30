import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  try {
    // <<< SỬA LẠI: Dùng đúng tên biến môi trường mặc định do Supabase cung cấp >>>
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    // Lấy key của Resend từ secret bạn đã set
    const resendApiKey = Deno.env.get('RESEND_API_KEY')!;

    console.log("Cron job triggered: Checking for upcoming todos...");

    const now = new Date();
    const oneMinuteFromNow = new Date(now.getTime() + 1 * 60 * 1000);

    const { data: todos, error } = await supabaseAdmin
      .from('todos')
      .select('title, content')
      .eq('recurrence_type', 'none')
      .gte('date_time', now.toISOString())
      .lt('date_time', oneMinuteFromNow.toISOString());
      
    if (error) throw error;
    
    if (todos.length === 0) {
      return new Response(JSON.stringify({ message: "No upcoming todos to notify." }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    for (const todo of todos) {
      console.log(`Sending notification for: ${todo.title}`);
      
      const resendPayload = {
        from: 'Lịch Công Việc <onboarding@resend.dev>',
        to: ['quypham.spam@gmail.com'], // <<< NHỚ THAY EMAIL CỦA BẠN
        subject: `Nhắc nhở: ${todo.title}`,
        html: `<p>Đã đến giờ thực hiện công việc: <strong>${todo.content}</strong></p>`,
      };

      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(resendPayload),
      });
    }

    return new Response(JSON.stringify({ message: `Processed ${todos.length} notifications.` }), {
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