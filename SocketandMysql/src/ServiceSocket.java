import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;


public class ServiceSocket {
	
	private ServerSocket ss;
	private Socket socket;  
    private BufferedReader in;  
    private PrintWriter out;  
    
    public  void Server()   

    {  
        try   
        {  
            ss = new ServerSocket(10000);  
              
            System.out.println("The server is waiting your input...");  
            socket = ss.accept();    
            while(true)   
            {  
            	if(ss!=null){
	                in = new BufferedReader(new InputStreamReader(socket.getInputStream()));  
	                out = new PrintWriter(socket.getOutputStream(), true);  
	                String line = in.readLine();  
	                  
	                System.out.println("you input is : " + line);  
	                  
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


