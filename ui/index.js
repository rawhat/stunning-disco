import * as React from 'react'
import {render} from 'react-dom'


class App extends React.Component {

  async componentDidMount() {
    const res = await fetch('http://api:3000/')
    const body = await res.json()
    console.log('body is', body)
  }

  render() {
    <div>Hello world</div>
  }
}

render(<App />, document.getElementById('app'))