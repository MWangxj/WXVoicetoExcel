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
	                Iterator iter=result.iterator();
	                for(;iter.hasNext();){
	                	String resultline=(String)iter.next();
	                	System.out.println( resultline);  
	                }
	                String line = in.readLine();
	                  
	                //out.println("you input is :" + line);  
	            	
	                if(line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")){
	                	out.close();  
	                    in.close();  
	                	socket=ss.accept(); 
	                } 
            	}else{
            	socket=ss.accept();
            	}    
            }
              
        } catch (IOException e) {  
            e.printStackTrace();  
        }  
    }  
    
    
}


