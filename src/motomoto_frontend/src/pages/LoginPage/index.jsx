import React, { useEffect, useState } from "react";
import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent } from "@dfinity/agent";
import { useCookies } from "react-cookie";
import { be, createActor } from "../../../../declarations/be";
import { useAuth } from "../../auth/AuthProvider";

const anonII = process.env.ANON_II;
const canisterID = process.env.BE_CANISTER_ID;

function LoginPage() {
  const [userID, setUserID] = useState(anonII);
  const [isValidUser, setValidUser] = useState(false);
  const [loginInfo, setLoginInfo] = useState("");
  const [fillPassword, setFillPassword] = useState("");
  const [password, setPassword] = useState("");
  const { login } = useAuth();

  const getInternetId = async () => {
    var actor = be;
    let authClient = await AuthClient.create();
    await new Promise((resolve) => {
      authClient.login({
        identityProvider:
          process.env.DFX_NETWORK === "ic"
            ? "https://identity.ic0.app"
            : `http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943`,
        onSuccess: () => resolve(),
        maxTimeToLive: BigInt(1 * 24 * 3600000000000),
      });
    });
    const identity = authClient.getIdentity();
    const agent = new HttpAgent({ identity });
    actor = createActor(canisterID, {
      agent,
    });

    var id = await actor.whoami();
    return id.toString();
  };

  // login to internet identity, after getting user id, check if user is valid
  // if valid user prompt to fill password
  const handleLogin = async (e) => {
    e.preventDefault();
    var iid = await getInternetId();
    setUserID(iid);
    be.isUser(iid)
      .then((res) => {
        if (res) {
          setFillPassword("continue");
        } else {
          setFillPassword("register");
        }
      })
      .catch((err) => {
        console.log(err);
      });
  };

  const continueLogin = async (e) => {
    e.preventDefault();
    setLoginInfo("");
    await be.login(userID, password).then((res) => {
      console.log(res);
      // the response if error is {err: 'Incorrect password'}
      if ("err" in res) {
        setLoginInfo("Incorrect password");
        setValidUser(false);
        setFillPassword("continue");
      } else {
        login(res.ok);
        setValidUser(true);
        setFillPassword("done");
      }
    });
  };

  const registerUser = async (e) => {
    e.preventDefault();
    await be.addPassword(userID, password).then((res) => {
      setFillPassword("continue");
    });
  };

  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <div>
        <form>
          <button id="login" onClick={handleLogin}>
            Continue with Internet Identity
          </button>
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
          <div></div>
        ) : null}
      </div>
    </div>
  );
}

export default LoginPage;
