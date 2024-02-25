import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import tp "../types";
import ut "../utils";

actor Auth {
    stable var user_data = Map.new<Principal.Principal, tp.UserData>();
    stable var session = Map.new<Principal.Principal, tp.Session>();

    public shared (msg) func whoami() : async Principal {
        msg.caller;
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
                    created_at = Time.now();
                    expired_at = Time.now() + tp.OneDay; // 7 days
                };

                Map.set(session, Map.phash, p, new_session);
                return #ok("Session created");
            };
            case (null) {
                return #err("Password not created");
            };
        };
    };

    public func logout(userId : Text) : async tp.Res<Text, Text> {
        var p = Principal.fromText(userId);
        var sess = Map.get(session, Map.phash, p);
        switch (sess) {
            case (?s) {
                Map.delete(session, Map.phash, p);
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

    public query func isAuth(userId : Text) : async Bool {
        var p = Principal.fromText(userId);
        var isUser = Map.has(user_data, Map.phash, p);
        if (not isUser) {
            return false;
        };
        var sess = Map.get(session, Map.phash, p);
        switch (sess) {
            case (?s) {
                var isNotExpired = Time.now() < s.expired_at;
                return isNotExpired;
            };
            case (null) {
                return false;
            };
        };
    };

};
