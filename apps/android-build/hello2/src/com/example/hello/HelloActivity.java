package com.example.hello2;

import android.app.Activity;
import android.os.Bundle;
import com.example.foo.Foo;
import com.example.bar.Bar;

public class HelloActivity extends Activity
{
    /** Called when the activity is first created. */
    @Override 
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        /*
        */
        int foo_icon = com.example.foo.R.drawable.ic_launcher;
        int foo_main = com.example.foo.R.layout.main;
        int foo_name = com.example.foo.R.string.app_name;

        Foo foo = new Foo();
        foo.foo();

        Bar bar = new Bar();
        bar.bar();
    }
}
