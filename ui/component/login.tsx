import * as React from 'react'
import {RouterProps} from '@reach/router'
import axios from 'axios'


export const Login: React.SFC<RouterProps> = () => {
  const usernameRef = (React as any).useRef(null)
  const passwordRef = (React as any).useRef(null)

  const post = async (path: string, username: string, password: string) => {
    const {data} = await axios.post(`http://localhost:3000${path}`, {
      username,
      password,
    })
    console.log('body is', data)
  }

  const login = (e: React.FormEvent) => {
    e.preventDefault()
    post('/login',  usernameRef.current.value, passwordRef.current.value)
  }

  const signUp = async (e: React.FormEvent) => {
    e.preventDefault()
    post('/user/create',  usernameRef.current.value, passwordRef.current.value)
  }
  return (
    <div>
      <h1>Welcome to the Stunning Disco!</h1>
      <form onSubmit={login}>
        <input
          ref={usernameRef} placeholder="username"
        />
        <input
          ref={passwordRef} placeholder="password"
          type='password'
        />
        <button type="submit">Login</button>
      </form>
      <button onClick={signUp}>Sign Up</button>
    </div>
  )
}
