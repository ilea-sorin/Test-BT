using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Test_Bt
{
    class Program
    {

        private string _url;

        public void SendTasks()
        {
            string cs = ConfigurationManager.ConnectionStrings["CS"].ToString();
            _url = ConfigurationManager.AppSettings["LegacySystem.URL"];

            using (SqlConnection conSel = new SqlConnection(cs))
            {
                string sel = "SELECT * FROM Tasks WHERE ISNULL(TaskProcessed, '0')='0'";
                SqlCommand cmdSel = new SqlCommand(sel, conSel);
                conSel.Open();

                using (SqlConnection conUpd = new SqlConnection(cs))
                {
                    string upd = "UPDATE Tasks SET TaskProcessed=@status WHERE TaskId=@taskid";
                    SqlCommand cmdUpd = new SqlCommand(upd, conUpd);
                    conUpd.Open();

                    using (SqlDataReader reader = cmdSel.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            int taskid = (int)reader["TaskId"];
                            
                            // seteaza ca fiind in lucru
                            cmdUpd.Parameters.Clear();
                            cmdUpd.Parameters.AddWithValue("taskid", taskid);
                            cmdUpd.Parameters.AddWithValue("status", "1");
                            cmdUpd.ExecuteNonQuery();

                            // trimite la sistemul de procesare a taskurilor
                            bool ok = SendToLegacySystem(reader);

                            // seteaza starea taskului dupa procesare
                            cmdUpd.Parameters.Clear();
                            cmdUpd.Parameters.AddWithValue("taskid", taskid);
                            cmdUpd.Parameters.AddWithValue("status", ok ? "2" : "3");
                            cmdUpd.ExecuteNonQuery();

                        }
                    }
                    conUpd.Close();
                }
                conSel.Close();
            }
        }

        private bool SendToLegacySystem(SqlDataReader reader)
        {
            bool ok = false;
            try
            {
                NameValueCollection nvc = new NameValueCollection();

                for (int i = 0; i < reader.FieldCount; i++)
                {
                    nvc.Add(reader.GetName(i), reader[reader.GetName(i)].ToString());
                }

                using (System.Net.WebClient client = new System.Net.WebClient())
                {
                    byte[] response = client.UploadValues(_url, nvc);
                    string result = System.Text.Encoding.UTF8.GetString(response);
                    ok = result.StartsWith("OK");
                }
            }
            catch(Exception ex)
            {
                System.Console.Out.WriteLine(ex.Message);
            }

            return ok;
        }
        static void Main(string[] args)
        {
            System.Console.Out.WriteLine("Start");

            Program p = new Program();
            p.SendTasks();

            System.Console.Out.WriteLine("End");
        }
    }
}
