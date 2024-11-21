import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://mduspmbnykokptyjvgoj.supabase.co'; 
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kdXNwbWJueWtva3B0eWp2Z29qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIxNzI1MDQsImV4cCI6MjA0Nzc0ODUwNH0.ucnGUCQEc-muyM2fQr552IpZ0v0FcPrrTiqAvA-2apU'; 

  static final SupabaseClient supabaseClient =
      SupabaseClient(supabaseUrl, supabaseAnonKey);
}
