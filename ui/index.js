import * as React from 'react'
import {render} from 'react-dom'


class App extends React.Component {

  async componentDidMount() {
    const res = await fetch('http://localhost:3000/')
    const body = await res.text()
    console.log('body is', body)
  }

  render() {
    return (
      <div>Hello, world!</div>
    )
  }
}

render(<App />, document.getElementById('app'))
