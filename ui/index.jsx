import * as React from 'react'
import {render} from 'react-dom'


class App extends React.Component {
        constructor(props) {
                super(props)
    this.login = this.login.bind(this)
  }
  
  async componentDidMount() {
    const res = await fetch('http://localhost:3000/')
    const body = await res.text()
    console.log('body is', body)
  }

  render() {
    return (
      <div>
        <h1>Welcome to the Stunning Disco!</h1>
        <form onSubmit={this.login}>
          <input ref={(username) => this.username = username} placeholder="username" />
          <input ref={(password) => this.password = password} placeholder="password" />
          <button type="submit">Login</button>
        </form>
      </div>
    )
  }

  async login (e) {
    e.preventDefault()
    const {username, password} = this
    const res = await fetch('http://localhost:3000/login', {
        method: "POST", 
        mode: 'cors',
        headers: {"Content-Type": "application/json"}, 
        body: JSON.stringify({username: username.textContent, password: password.textContent}) 
      })
    const body = await res.json()
    console.log('login body is', body)
  } 
}

render(<App />, document.getElementById('app'))
