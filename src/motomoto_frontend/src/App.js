import React, { useEffect, useState } from 'react';
import { pubsub } from "../../declarations/pubsub";
import { db } from "../../declarations/db";
import { Principal } from '@dfinity/principal';

function App() {
  const userID = "be";
  const [baggageList, setBaggageList] = useState([]);
  const [baggageId, setBaggageId] = useState("");
  const [displayBaggage, setDisplayBaggage] = useState(false);
  const [rerender, setRerender] = useState(false);

  function callback(principal, str) {
    // Your callback logic here
    console.log("Callback called with principal:", principal, "and string:", str);
}

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
  }, [rerender])


  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <div>
        <h2>User ID: {userID}</h2>
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
