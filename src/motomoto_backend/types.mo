import Time "mo:base/Time";
import Result "mo:base/Result";
import List "mo:base/List";
import Bool "mo:base/Bool";

module {
    public type BaggageData = {
        baggage_id : Text;
        // owner is the user_id
        owner : Text;
        departure : Airport;
        destination : Airport;
        airline : Text;
        weight : Nat;
        dimension : Dimension;
        category : Text;
        is_fragile : Bool;
        events : [BaggageEvent];
    };

    public type BaggageStatus = { #CheckIn; #InTransit; #Delivered; #Lost };

    public type BaggageEvent = {
        status : BaggageStatus;
        description : Text;
        timestamp : Time.Time;
        photo : Text;
        location : Airport;
    };

    type Airport = {
        code : Text;
        name : Text;
    };

    type Dimension = {
        x : Nat;
        y : Nat;
        z : Nat;
    };

    public type BaggageMapKey = {
        // user_id : Text;
        baggage_id : Text;
    };

    public type Res<T, E> = Result.Result<T, E>;

    public type BaggageReference = {
        baggage_id : Text;
        callback : shared (BaggageMapKey, UpdatePayload) -> async Bool;
    };

    public type UpdatePayload = {
        // b_status : BaggageStatus;
        b_event : BaggageEvent;
    };

    public type PublishMessage = {
        b_user_id : Text;
        b_key : BaggageMapKey;
        b_payload : UpdatePayload;
    };

    public type Ls<K> = List.List<K>;
};
