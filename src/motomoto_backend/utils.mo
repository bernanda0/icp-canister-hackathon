import Map "mo:map/Map";
import Prim "mo:prim";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import tp "./types"

module {
    func hashBaggageMapKey(key : tp.BaggageMapKey) : Nat32 {
        Prim.hashBlob(Prim.encodeUtf8(key.baggage_id)) & 0x3fffffff;
    };

    func keyAreEqual(key1 : tp.BaggageMapKey, key2 : tp.BaggageMapKey) : Bool {
        return key1.baggage_id == key2.baggage_id;
    };

    public let khash = (hashBaggageMapKey, keyAreEqual) : Map.HashUtils<tp.BaggageMapKey>;
};
