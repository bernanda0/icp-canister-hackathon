actor Hello {
  stable var value = 0;

  public func getValue() : async Nat {
    return value;
  };

  public func inc() : async Nat {
    value += 1;
    return value;
  };

  public func dec() : async Nat {
    value -= 1;
    return value;
  };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
