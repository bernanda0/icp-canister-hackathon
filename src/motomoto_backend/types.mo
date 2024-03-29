import Time "mo:base/Time";
import Result "mo:base/Result";
import List "mo:base/List";
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Text "mo:base/Text";

module {
    public type UserData = {
        user_id : Principal.Principal;
        hashed_password : Hash.Hash;
        is_admin : Bool;
        wallet : Wallet;
    };

    type Wallet = {
        // wallet id is the public key
        wallet_id : Text;
        balance : Float;
    };

    public type UpdateUserParam = {
        wallet : Wallet;
    };

    // public type SessionId = Principal.Principal;

    public type Session = {
        user_id : Text;
        created_at : Time.Time;
        expired_at : Time.Time;
    };

    public type IsAuthRespose = {
        valid : Bool;
        user_id : Text;
    };

    public let OneDay = 86400000000000;

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

    public type BaggageDataSummary = {
        baggage_id : Text;
        departure_code : Text;
        destination_code : Text;
        last_events : {
            status : BaggageStatus;
            description : Text;
        };
    };

    public type BaggageStatus = { #CheckIn; #InTransit; #Delivered; #Lost };

    public type BaggageEvent = {
        status : BaggageStatus;
        description : Text;
        timestamp : Time.Time;
        photo : Photo;
        location : Airport;
    };

    type Photo = {
        cid : Text;
    };

    public type Airport = {
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
