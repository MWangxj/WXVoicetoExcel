import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Iterator;
import java.util.stream.Stream;


public class ServiceSocket {
	
	private ServerSocket ss;
	private Socket socket;  
    private BufferedReader in;  
    private PrintWriter out;  
    
    public  void Server()   

    {  
        try   
        {  
            ss = new ServerSocket(55555);  
              
            System.out.println("The server is waiting your input...");  
            socket = ss.accept();    
            while(true)   
            {  
            	if(ss!=null){
	                in = new BufferedReader(new InputStreamReader(socket.getInputStream()));  
	                out = new PrintWriter(socket.getOutputStream(), true);  
	                Stream<String> result=in.lines();
	                String resultStr="";
	                Iterator iter=result.iterator();
//	                System.out.println( result.s);  
	                if(iter.hasNext()){
	                	String resultline=(String)iter.next();
	                	resultStr+=resultline;
	                	System.out.println( resultline);  
	                }
	                System.out.println( resultStr);  
//	                System.out.println( "***********");
//	                String ssss=in.lines().toString();
//	                System.out.println(ssss);
	                String sqlStr="insert into Data(JSONData) values ('"+resultStr+"')";
	                DBHelper db=new DBHelper(sqlStr);
	                db.close();
	               
            	}else{
            	socket=ss.accept();
            	}    
            }
              
        } catch (IOException e) {  
            e.printStackTrace();  
        }  
    }  
    
    
}


