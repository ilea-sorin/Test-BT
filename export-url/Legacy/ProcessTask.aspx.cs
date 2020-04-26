using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class ProcessTask : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Clear();
        string taskid = Request.Form["TaskId"];
        if (taskid != null)
        {
            int tid = int.Parse(taskid);
            if (tid % 3 == 0)
                Response.Write("ERROR");
            else
                Response.Write("OK");
        }

        Response.End();
    }
}