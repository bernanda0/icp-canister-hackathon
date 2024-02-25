import Time "mo:base/Time";

module {
    public type BaggageData = {
        baggage_id : Text;
        owner : Text;
        destination : Text;
        weight : Nat;
        status : BaggageStatus;
        event : BaggageEvent;
    };

    public type BaggageStatus = { #CheckIn; #InTransit; #Delivered; #Lost };

    public type BaggageEvent = {
        event : Text;
        timestamp : Time.Time;
    };

    public type BaggageMapKey = {
        user_id : Text;
        baggage_id : Text;
    }
};
