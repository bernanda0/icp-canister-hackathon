import tp "../types";
import ut "../utils";
import Map "mo:map/Map";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import List "mo:base/List";
import Text "mo:base/Text";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";

actor BE {
    // DATABASE DEFINITION
    // 1. For baggage
    stable var baggage_data = Map.new<tp.BaggageMapKey, tp.BaggageData>();

    // 2. For user
    stable var user_data = Map.new<Principal.Principal, tp.UserData>();
    stable var session = Map.new<Text, tp.Session>();

    // 3. For pubsub
    stable var subscribers = Map.new<Text, tp.Ls<tp.BaggageReference>>();
    stable var lookup_subbag = Map.new<Text, Null>();

    // Exposed function or query
    // 1. For baggage
    public func addBaggageData(user_id : Text, value : tp.BaggageData) : async tp.Res<tp.BaggageData, Text> {
        // userId used for authentication and verification
        var key : tp.BaggageMapKey = { baggage_id = value.baggage_id };
        Map.set(baggage_data, ut.khash, key, value);
        if (Map.has(baggage_data, ut.khash, key)) {
            return #ok(value);
        };
        return #err("Failed to add baggage data");
    };
    public shared func updateBaggageEvent(key : tp.BaggageMapKey, baggagePayload : tp.UpdatePayload) : async Bool {
        var baggageData = Map.get(baggage_data, ut.khash, key);
        switch (baggageData) {
            case (?myDt) {
                var existing_event = Buffer.fromArray<tp.BaggageEvent>(myDt.events);
                existing_event.add(baggagePayload.b_event);

                var newBaggageData : tp.BaggageData = {
                    baggage_id = myDt.baggage_id;
                    owner = myDt.owner;
                    departure = myDt.departure;
                    destination = myDt.destination;
                    airline = myDt.airline;
                    weight = myDt.weight;
                    dimension = myDt.dimension;
                    category = myDt.category;
                    is_fragile = myDt.is_fragile;
                    events = Buffer.toArray(existing_event);
                };

                Map.set(baggage_data, ut.khash, key, newBaggageData);
                return true;
            };
            case null {
                return false;
            };
        };

    };
    public query func getBaggageData(userId : Text, key : tp.BaggageMapKey) : async tp.Res<tp.BaggageData, Text> {
        // check if the userId is the owner of the baggage
        var baggageData = Map.get(baggage_data, ut.khash, key);
        switch (baggageData) {
            case (?myDt) {
                if (myDt.owner != userId) {
                    return #err("You are not the owner of this baggage.");
                };
                return #ok(myDt);
            };
            case null {
                return #err("Failed to get baggage data.");
            };
        };
    };
    public func deleteBaggageData(key : tp.BaggageMapKey) : async tp.Res<tp.BaggageData, Text> {
        var baggageData = Map.get(baggage_data, ut.khash, key);
        switch (baggageData) {
            case (?myDt) {
                Map.delete(baggage_data, ut.khash, key);
                return #ok(myDt);
            };
            case null {
                return #err("Failed deleting, no data found");
            };
        };
    };

    // 2. For User
    public shared (msg) func whoami() : async Principal {
        msg.caller;
    };
    public query func isAuth(session_id : Text) : async tp.IsAuthRespose {
        var sess = Map.get(session, Map.thash, session_id);
        var isValid = false;
        var userId = "";
        switch (sess) {
            case (?s) {
                var isNotExpired = Time.now() < s.expired_at;
                if (isNotExpired) {
                    isValid := true;
                    userId := s.user_id;
                };
            };
            case(null){};
        };
        let res : tp.IsAuthRespose = {
            valid = isValid;
            user_id = userId;
        };
        return res;
    };
    public query func isUser(userId : Text) : async Bool {
        var p = Principal.fromText(userId);
        return Map.has(user_data, Map.phash, p);
    };
    public func login(userId : Text, password : Text) : async tp.Res<Text, Text> {
        var p = Principal.fromText(userId);
        let user = Map.get(user_data, Map.phash, p);

        switch (user) {
            case (?u) {
                var input_pass = await ut.hashPassword(password);
                if (not Hash.equal(u.hashed_password, input_pass)) {
                    return #err("Incorrect password");
                };

                var new_session : tp.Session = {
                    user_id = userId;
                    created_at = Time.now();
                    expired_at = Time.now() + tp.OneDay; // 7 days
                };

                let g = Source.Source();
                var new_session_id = UUID.toText(await g.new());

                Map.set(session, Map.thash, new_session_id, new_session);
                return #ok(new_session_id);
            };
            case (null) {
                return #err("Password not created");
            };
        };
    };
    public func logout(session_id : Text) : async tp.Res<Text, Text> {
        var sess = Map.get(session, Map.thash, session_id);
        switch (sess) {
            case (?s) {
                Map.delete(session, Map.thash, session_id);
                return #ok("Session deleted");
            };
            case (null) {
                return #err("Session not found");
            };
        };
    };
    public func addPassword(userId : Text, password : Text) : async tp.Res<Text, Text> {
        var p = Principal.fromText(userId);
        var hashed_pass = await ut.hashPassword(password);
        var new_user : tp.UserData = {
            user_id = p;
            hashed_password = hashed_pass;
            is_admin = false;
            wallet = {
                wallet_id = "";
                balance = 0;
            };
        };

        Map.set(user_data, Map.phash, p, new_user);
        return #ok("Password added");
    };
    // public func updateUserData(updateParam: tp.UpdateUserParam) {
    // };

    // 3. For pubsub

    public func subscribe(userId : Text, baggageRef : tp.BaggageReference) {
        var baggageIdExist = await bagIdExists(baggageRef.baggage_id);
        if (not baggageIdExist) {
            return ();
        };

        let look_up_key = userId # "" # baggageRef.baggage_id;
        let look_up_exists = Map.has(lookup_subbag, Map.thash, look_up_key);
        if (look_up_exists) {
            return ();
        };
        Map.set(lookup_subbag, Map.thash, look_up_key, null);

        let key = userId;
        let subscribed_baggages = Map.get(subscribers, Map.thash, key);

        switch (subscribed_baggages) {
            case (?suffering) {
                var new_list = List.push(baggageRef, suffering);
                Map.set(subscribers, Map.thash, key, new_list);
            };
            // still empty
            case null {
                var new_list = List.nil<tp.BaggageReference>();
                new_list := List.push(baggageRef, new_list);
                Map.set(subscribers, Map.thash, key, new_list);
            };
        };
    };

    public func publish(message : tp.PublishMessage) : async tp.Res<Text, Text> {
        let key = message.b_user_id;
        let subscribed_baggages = Map.get(subscribers, Map.thash, key);

        switch (subscribed_baggages) {
            case (?cry) {
                for (bRef in List.toIter(cry)) {
                    if (bRef.baggage_id == message.b_key.baggage_id) {
                        var res = await bRef.callback(message.b_key, message.b_payload);
                        if (res) {
                            return #ok("Update Success");
                        };
                        return #err("Failed to update baggage");
                    };
                    return #err("Baggage not found");
                };
                return #err("Baggage not found");
            };
            case null {
                return #err("No subscribed bag found");
            };
        };
    };

    public func init(session_id : Text, baggageId : Text) {
        var res = await isAuth(session_id);
        if (not res.valid) {
            return ();
        };
        let userId = res.user_id;
        var ok2 = await getBaggageData(userId, { baggage_id = baggageId });
        switch (ok2) {
            case (#ok(data)) {
                subscribe(
                    userId,
                    {
                        baggage_id = baggageId;
                        callback = updateBaggageEvent;
                    },
                );
            };
            case (#err(err)) {
                return ();
            };
        };
    };

    public shared query func getSubscribedBag(userId : Text) : async [Text] {
        let subscribed_baggages = Map.get(subscribers, Map.thash, userId);
        switch (subscribed_baggages) {
            case (?cry) {
                var buffer_id = Buffer.Buffer<Text>(3);

                for (bRef in List.toIter(cry)) {
                    buffer_id.add(bRef.baggage_id);
                };

                return Buffer.toArray(buffer_id);
            };
            case null {
                return [];
            };
        };
    };

    // TO BE DELETED (FOR DEVELOPMENT ONLY)
    public query func bagIdExists(bagId : Text) : async Bool {
        return Map.has(baggage_data, ut.khash, { baggage_id = bagId });
    };

    public func resetBaggageData() : async Text {
        baggage_data := Map.new<tp.BaggageMapKey, tp.BaggageData>();
        return debug_show (baggage_data);
    };

    // reset pub sub data
    public func resetSubscriberData() : async Text {
        subscribers := Map.new<Text, tp.Ls<tp.BaggageReference>>();
        return debug_show ("Subs data reset");
    };

    // reset pub sub data
    public func resetLookUp() : async Text {
        lookup_subbag := Map.new<Text, Null>();
        return debug_show ("Lookup data reset");
    };

};
