import Map "mo:map/Map";
import Prim "mo:prim";
import tp "./types"

module {
    func hashBaggageMapKey(key : tp.BaggageMapKey) : Nat32 {
        var string_key = key.user_id # "" # key.baggage_id;
        Prim.hashBlob(Prim.encodeUtf8(string_key)) & 0x3fffffff;
    };

    func keyAreEqual(key1 : tp.BaggageMapKey, key2 : tp.BaggageMapKey) : Bool {
        var string1 = key1.user_id # "" # key1.baggage_id;
        var string2 = key2.user_id # "" # key2.baggage_id;
        return string1 == string2;
    };

    public let khash = (hashBaggageMapKey, keyAreEqual) : Map.HashUtils<tp.BaggageMapKey>;
};
