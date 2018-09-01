import * as React from 'react'
import {RouterProps} from '@reach/router'
import axios from 'axios'


export class Login extends React.Component<RouterProps> {

  private username: HTMLInputElement | undefined
  private password: HTMLInputElement | undefined

  constructor(props) {
    super(props)
    this.login = this.login.bind(this)
  }

  async componentDidMount() {
    const {data} = await axios.get('http://localhost:3000/')
    console.log('data is', data)
  }

  render() {
    return (
      <div>
        <h1>Welcome to the Stunning Disco!</h1>
        <form onSubmit={this.login}>
          <input
            ref={(username) => this.username = username} placeholder="username"
          />
          <input
            ref={(password) => this.password = password} placeholder="password"
            type='password'
          />
          <button type="submit">Login</button>
        </form>
      </div>
    )
  }

  async login(e: React.FormEvent) {
    e.preventDefault()
    const {username, password} = this
    const {data} = await axios.post('http://localhost:3000/login', {
      username: username.value,
      password: password.value,
    })
    console.log('login body is', data)
  }
}
