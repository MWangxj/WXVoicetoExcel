package com.wxj.dao;

public class DaoException extends Exception {
	
	private String message;  
    public DaoException(){}  
    public DaoException(String message){  
        this.message = message;  
    }  
    public String getMessage() {  
        return message;  
    }  
    public void setMessage(String message) {  
        this.message = message;  
    }  
      
    public String toString(){  
        return message;  
    }  
  

}
