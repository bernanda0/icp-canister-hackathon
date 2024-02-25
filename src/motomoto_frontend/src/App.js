import React, { useEffect, useState } from 'react';
import { pubsub } from "../../declarations/pubsub";
import { db } from "../../declarations/db";
import { auth, createActor } from "../../declarations/auth";
import { AuthClient } from '@dfinity/auth-client';
import { HttpAgent } from '@dfinity/agent';

// DIBUAT ENV AJA INI, ANONYMOUS
const anonII = "2vxsx-fae"

function App() {
  const [userID, setUserID] = useState(anonII);
  const [baggageList, setBaggageList] = useState([]);
  const [baggageId, setBaggageId] = useState("");
  const [displayBaggage, setDisplayBaggage] = useState(false);
  const [rerender, setRerender] = useState(false);
  const [isValidUser, setValidUser] = useState(false);
  const [fillPassword, setFillPassword] = useState("");
  const [password, setPassword] = useState("");

  const subscribe = async () => {
    pubsub.init(userID, baggageId).then(() => {
      setRerender(!rerender);
      console.log("subscribed");
    });
  }

  useEffect(() => {
    const getBaggageList = async () => {
      pubsub.getSubscribedBag(userID).then((baggageLs) => {
        setBaggageList(baggageLs);
      })
    }

    getBaggageList();
  }, [userID, rerender])

  const getInternetId = async () => {
    var actor = auth;
    let authClient = await AuthClient.create();
    await new Promise((resolve) => {
      authClient.login({
        identityProvider:
          process.env.DFX_NETWORK === "ic"
            ? "https://identity.ic0.app"
            : `http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943`,
        onSuccess: resolve,
        maxTimeToLive: 1 * 24 * 3600000000000
      });
    });
    const identity = authClient.getIdentity();
    const agent = new HttpAgent({ identity });
    actor = createActor("bw4dl-smaaa-aaaaa-qaacq-cai", {
      agent,
    });

    var id = await actor.whoami();
    return id.toString();
  }

  // login to internet identity, after getting user id, check if user is valid
  // if valid user prompt to fill password
  const login = async (e) => {
    e.preventDefault();
    var iid = await getInternetId();
    setUserID(iid);
    auth.isUser(iid).then((res) => {
      if (res) {
        setFillPassword("continue");
      } else {
        setFillPassword("register");
      }
    }).catch((err) => {
      console.log(err);
    })

  };

  const continueLogin = async (e) => {
    e.preventDefault();
    await auth.login(userID, password).then((res) => {
      setValidUser(true);
      setFillPassword("done");
    });
  };

  const registerUser = async (e) => {
    e.preventDefault();
    await auth.addPassword(userID, password).then((res) => {
      setFillPassword("continue");
    });
  }

  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <form>
        <button id="login" onClick={login}>Login!</button>
      </form>
      <br />
      <div>
        <h2>User ID: {userID}</h2>
        <h2>Valid User : {isValidUser ? "TRUE" : "FALSE"}</h2>
        {fillPassword === "continue" ? (
          <div>
            <h2>Continue</h2>
            <input type="text" onChange={(e) => setPassword(e.target.value)} />
            <button onClick={continueLogin}>Continue</button>
          </div>
        ) : fillPassword === "register" ? (
          <div>
            <h2>Continue fill password</h2>
            <input type="text" onChange={(e) => setPassword(e.target.value)} />
            <button onClick={registerUser}>Create Password</button>
          </div>
        ) : fillPassword === "done" ? (
          <div>
          </div>
        ) : null}
        {/* input baggage id to subscribe to updates for that baggage id*/}
        <input type="text" onChange={(e) => setBaggageId(e.target.value)} />
        <button onClick={subscribe}>Sub</button>
        <h2>Baggage List: </h2>
        <ul>
          {/*baggage list is array of string */}
          {baggageList.map((bid) => {
            return <li key={bid} onClick={() => { setBaggageId(bid); setDisplayBaggage(true) }}>{bid}</li>
          })}
        </ul>
        <hr />
        {displayBaggage ? <BaggageData userId={userID} baggageId={baggageId} /> : <div>No baggage selected</div>}
      </div>
    </div>
  );
}

function BaggageData({ userId, baggageId }) {
  const [baggageData, setBaggageData] = useState({});

  useEffect(() => {
    const getBaggageData = async () => {
      db.getBaggageData(userId, { baggage_id: baggageId }).then((baggageData) => {
        console.log(baggageData);
        setBaggageData(baggageData);
      })
    }

    // call getBaggageData every x secs
    setInterval(() => { getBaggageData() }, 10000);

  }, [userId, baggageId])

  return <div>
    <h2>Polling Baggage Data </h2>
    <h3>Owner: {baggageData.owner}</h3>
    <h3>Baggage ID: {baggageData.baggage_id}</h3>
    <h3>Weight: {String(baggageData.weight)}</h3>
    <h3>Destination: {baggageData.destination}</h3>
    <h3>Status: {baggageData.status ? Object.keys(baggageData.status)[0] : 'N/A'}</h3>
    <h3>Events:</h3>
    <ul>
      {baggageData.event && baggageData.event.map((eventData, index) => (
        <li key={index}>
          <p>Event: {eventData.event}</p>
          <p>Timestamp: {String(eventData.timestamp)}</p>
        </li>
      ))}
    </ul>
  </div>
}


export default App;
