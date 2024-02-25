import Time "mo:base/Time";
import Result "mo:base/Result";
import List "mo:base/List";
import Bool "mo:base/Bool";

module {
    public type BaggageData = {
        baggage_id : Text;
        // owner is the user_id
        owner : Text;
        destination : Text;
        weight : Nat;
        status : BaggageStatus;
        event : [BaggageEvent];
    };

    public type BaggageStatus = { #CheckIn; #InTransit; #Delivered; #Lost };

    public type BaggageEvent = {
        event : Text;
        timestamp : Time.Time;
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
        b_status : BaggageStatus;
        b_event : BaggageEvent;
    };

    public type PublishMessage = {
        b_user_id : Text;
        b_key : BaggageMapKey;
        b_payload : UpdatePayload;
    };

    public type Ls<K> = List.List<K>;
};
