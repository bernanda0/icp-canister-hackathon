import React, { useEffect, useState } from 'react';
import { be, createActor } from "../../declarations/be";
import { AuthClient } from '@dfinity/auth-client';
import { HttpAgent } from '@dfinity/agent';

// DIBUAT ENV AJA INI, ANONYMOUS
const anonII = process.env.ANON_II
const tatumAPIKey = process.env.TATUM_API_KEY

function App() {
  const [userID, setUserID] = useState(anonII);
  const [baggageList, setBaggageList] = useState([]);
  const [baggageId, setBaggageId] = useState("");
  const [displayBaggage, setDisplayBaggage] = useState(false);
  const [rerender, setRerender] = useState(false);
  const [isValidUser, setValidUser] = useState(false);
  const [loginInfo, setLoginInfo] = useState("");
  const [fillPassword, setFillPassword] = useState("");
  const [password, setPassword] = useState("");
  const [image, setImage] = useState(null);
  const [CID, setCID] = useState("");
  const [imageUrl, setImageUrl] = useState('');

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    setImage(file);
  };

  const handleUpload = async () => {
    if (!image) {

      alert('Please select an image to upload');
      return;
    }

    const formData = new FormData();
    formData.append('file', image);

    try {
      const response = await fetch('https://api.tatum.io/v3/ipfs', {
        method: 'POST',
        headers: {
          'x-api-key': tatumAPIKey // Replace <mykey> with your API key
        },
        body: formData
      });

      const data = await response.text();
      console.log('IPFS Response:', data);

      if (response.ok) {
        setCID(JSON.parse(data).ipfsHash)
      }
    } catch (error) {
      console.error('Error uploading image:', error);
    }
  };

  const handleFetchImage = async () => {
    try {
      const response = await fetch(`https://api.tatum.io/v3/ipfs/${CID}`, {
        method: 'GET',
        headers: {
          'x-api-key': tatumAPIKey
        }
      });

      if (!response.ok) {
        throw new Error('Failed to fetch image');
      }

      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      setImageUrl(url);
    } catch (error) {
      console.error('Error fetching image:', error);
    }
  };


  const subscribe = async () => {
    be.init(userID, baggageId).then(() => {
      setRerender(!rerender);
      console.log("subscribed");
    });
  }

  useEffect(() => {
    const getBaggageList = async () => {
      be.getSubscribedBag(userID).then((baggageLs) => {
        setBaggageList(baggageLs);
      })
    }

    getBaggageList();
  }, [userID, rerender])

  const getInternetId = async () => {
    var actor = be;
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
    actor = createActor("b77ix-eeaaa-aaaaa-qaada-cai", {
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
    be.isUser(iid).then((res) => {
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
    setLoginInfo("");
    await be.login(userID, password).then((res) => {
      console.log(res);
      // the response if error is {err: 'Incorrect password'}
      if (res.err) {
        setLoginInfo("Incorrect password");
        setValidUser(false);
        setFillPassword("continue");
      } else {
        setValidUser(true);
        setLoginInfo("Login Success");
        setFillPassword("done");
      }

    });
  };

  const registerUser = async (e) => {
    e.preventDefault();
    await be.addPassword(userID, password).then((res) => {
      setFillPassword("continue");
    });
  }

  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <div>
        <h2>Image Uploader</h2>
        <input type="file" accept="image/*" onChange={handleImageChange} />
        <button onClick={handleUpload}>Upload Image</button>
        <h3>CID : {CID}</h3>
        <button onClick={handleFetchImage}>Fetch Image</button>
        {imageUrl && (
          <div>
            <h3>Image Preview</h3>
            <img src={imageUrl} alt="wkwk" style={{ maxWidth: '25%' }} />
          </div>
        )}
      </div>
      <br />
      <div>
        <form>
          <button id="login" onClick={login}>Login!</button>
        </form>
        <h2>User ID: {userID}</h2>
        <h2>Authenticated : {isValidUser ? "TRUE" : "FALSE"}</h2>
        <h2>{loginInfo}</h2>
        {fillPassword === "continue" ? (
          <div>
            <h3>Fill Password</h3>
            <input type="text" onChange={(e) => setPassword(e.target.value)} />
            <button onClick={continueLogin}>Continue</button>
          </div>
        ) : fillPassword === "register" ? (
          <div>
            <h3>Create Password</h3>
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
