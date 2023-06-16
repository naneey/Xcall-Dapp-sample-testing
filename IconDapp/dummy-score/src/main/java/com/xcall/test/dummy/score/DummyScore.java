package com.xcall.test.dummy.score;

import score.annotation.External;

// contract connected in dapp

public class DummyScore {

    @External(readonly = true)
    public String name(){
        return "Dummy score";
    }

    // returns the byte[] of the parameter
    @External(readonly = true)
    public byte[] nameInBytes(String name){
        return name.getBytes();
    }
}
