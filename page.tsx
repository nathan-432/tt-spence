import { createClient } from "@/lib/supabase/server";
import SocialApp from "@/components/social-app";
export default async function Home() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  let profile = null;
  if (user) {
    const { data } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
    profile = data;
  }
  return <SocialApp initialUser={user ? { id: user.id, email: user.email ?? "", profile } : null} />;
}