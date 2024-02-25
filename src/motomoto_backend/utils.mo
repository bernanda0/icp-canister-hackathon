import Map "mo:map/Map";
import Prim "mo:prim";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import tp "./types"

module {
    func hashBaggageMapKey(key : tp.BaggageMapKey) : Nat32 {
        Prim.hashBlob(Prim.encodeUtf8(key.baggage_id)) & 0x3fffffff;
    };

    func keyAreEqual(key1 : tp.BaggageMapKey, key2 : tp.BaggageMapKey) : Bool {
        return key1.baggage_id == key2.baggage_id;
    };

    public let khash = (hashBaggageMapKey, keyAreEqual) : Map.HashUtils<tp.BaggageMapKey>;

    public func isAuth(p : Principal) : async Bool {
        if (Principal.isAnonymous(p)) {
            return false;
        };

        // if ()

        return true;
    };

    public func hashPassword(password : Text) : async Hash.Hash {
        return Prim.hashBlob(Prim.encodeUtf8(password)) & 0x7ffffff7;
    };

    public func isSessionValid(session : tp.Session) : async Bool {
        if (session.expired_at < Time.now()) {
            return false;
        };
        return true;
    }
};
