import React, {
  useContext,
  useState,
  useEffect,
  useMemo,
  createContext,
} from "react";
import { useNavigate } from "react-router-dom";
import { useCookies } from "react-cookie";
import { be } from "../../../declarations/be";

const AuthContext = createContext({
  user: null,
  login: (data) => {},
  logout: () => {},
  isAdmin: false,
  hasSession: false,
});

export const useAuth = () => {
  return useContext(AuthContext);
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [hasSession, setHasSession] = useState(false);
  const [cookies, setCookie, removeCookie] = useCookies(["sess_id"]);
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);

  const clearAllCookies = () => {
    removeCookie("sess_id");
    // Object.keys(cookies).forEach((cookieName) => {
      
    // });
  };

  useEffect(() => {
    checkSession();
  }, [cookies]);

  const checkSession = async () => {
    const sessionId = cookies["sess_id"];
    if (sessionId) {
      const res = await be.isAuth(sessionId);
      if (res.valid) {
        setUser(res.user_id);
        setHasSession(true);
        navigate("/home");
      } else {
        setUser(null);
        setHasSession(false);
        logout();
      }
    }
  };

  // call this function when you want to authenticate the user
  const login = async (data) => {
    setCookie("sess_id", data, { path: "/", maxAge: 31536000 });
  };

  const logout = async () => {
    clearAllCookies();
    // call be.logout
    setTimeout(() => {
      navigate("/login");
    }, 1000);
  };

  const value = useMemo(
    () => ({
      isAdmin,
      user,
      login,
      logout,
      hasSession
    }),
    [user],
  );

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
