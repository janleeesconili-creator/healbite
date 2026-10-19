const SUPABASE_URL = 'https://jlqfwaxzlemnmtetycqh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpscWZ3YXh6bGVtbm10ZXR5Y3FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMzc4NDcsImV4cCI6MjEwNjkxMzg0N30.X5Bqz7GZzGdE4B0WkSPL0m91Iu-t43Mohaeax8hUhoE';

module.exports = async function handler(_request, response) {
  try {
    const result = await fetch(`${SUPABASE_URL}/rest/v1/rpc/keep_healbite_alive`, {
      method: 'POST',
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: '{}',
    });

    if (!result.ok) {
      throw new Error(`Supabase returned ${result.status}`);
    }

    response.status(200).json({ ok: true, checkedAt: new Date().toISOString() });
  } catch (error) {
    response.status(500).json({ ok: false, error: error.message });
  }
};
