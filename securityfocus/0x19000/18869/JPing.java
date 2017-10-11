// $Id: JPing.java 8 2006-07-02 09:35:47Z tuergeist $
public class JPing {
	static String[] myArgs;
	
	private static void showHelp() {
		System.err.println("YAOP - Yet another object pinger v0.1\n a JacORB pingo clone");
        System.err.println("Usage: java JPing -p <IOR> [<TypeID>]");
        System.err.println("Options:");
        System.err.println("\t -p <IOR> \n\t\t pings an CORBA object" +
        					"\n\t\tYou can also use corbaloc instead of stringified IORs\n" +
        				   "\t\te.g. corbaloc::127.0.0.1:1234/foobarfoofoo \n" +
        				   "\t\tTypeID is optional e.g. IDL:Hello:1.0\n");
        System.exit( 1 );
	}
	public static String[] getMyArgs() {
		return myArgs;
	}

	public static void setMyArgs(String[] mArgs) {
		myArgs = mArgs;
	}
	public static void main(String[] args) {
		setMyArgs( args );
		
		if( args.length<2 || args.length > 5 )
        {
			showHelp();
        }
		
		if (args[0].equalsIgnoreCase("-p")) {
	        pingObject();
	        return;
	    }	
		showHelp();
	}
	
	static void pingObject () {
		String[] args = getMyArgs();
		String type = new String();
		org.omg.CORBA.ORB orb = org.omg.CORBA.ORB.init(args,null);
		org.omg.CORBA.Object o= null;
        String iorString = null;


        if( args.length < 2 || args.length > 3)
        {
			showHelp();
        }
        iorString = args[1];
        if (args.length==3) {
        	type = new String(args[2]); // TypeID
        }
        
        System.out.print("orb.string_to_object \t\t ... ");
        try {
        	o = orb.string_to_object( iorString );
        }
        catch (Exception e) {
        	System.err.println("Exception caught; " + e.toString());
        	System.exit(1);
        }
        if( o == null )
        {
            System.err.println("Could not convert " + iorString + " to an object");
        }
        else
        {
        	System.out.println("ok");
        	System.out.print("Object exists? " );
        	try
            {
        			boolean exists = !o._non_existent();
                	System.out.println("\t\t\t ... "	+ exists);
                	if(exists && type.length()>8) {
                		System.out.print("Object is_a("+type+")");
                		System.out.println("\t ... " + o._is_a( type ) );
                	}

            }
        	catch (org.omg.CORBA.OBJECT_NOT_EXIST e)
            {
                System.err.println("\t ... no!\n" + e );
            }
            catch (org.omg.CORBA.OBJ_ADAPTER e)
            {
                System.err.println("\nAdapter error!\n\n" + e );
            }
        	catch (Exception e) {
        		System.err.println("Exception caught; " + e.toString());
        	}
            /*
            catch (org.omg.CORBA.SystemException e)
            {
                System.err.println("\nSystem Exception!\n\n" + e );
            }
*/
        }
        return;
	}
}
