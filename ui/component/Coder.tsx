import * as React from 'react'
import {Channel} from 'phoenix'
import {RouterProps} from '@reach/router'
import {Socket} from 'phoenix'
import MonacoEditor from 'react-monaco-editor'
import axios from 'axios'

export class Coder extends React.Component<RouterProps> {

  private channel: Channel
  private ws: Socket

  state = {
    code: '',
    language: 'javascript', // TODO: should probably receive a prop at some point
    result: '',
  }

  constructor(props) {
    super(props)
    this.ws = new Socket('ws://localhost:3000/coder')
    // TODO: don't hardcode the username
    this.channel = this.ws.channel("logs:test")
    this.channel.on("message", this.onMessage)
    //this.ws.onmessage = this.onMessage
    //this.ws.onopen = this.onOpen
    this.submitCode = this.submitCode.bind(this)
  }

  render() {
    return (
      <div>
        <button onClick={this.submitCode}>Submit</button>
        <select onChange={this.changeLanguage}>
          <option value='javascript'>JavaScript</option>
          <option value='python'>Python</option>
        </select>
        <div>
          <MonacoEditor
            editorDidMount={this.editorDidMount}
            height='600'
            language={this.state.language}
            onChange={this.onChange}
            options={{selectOnLineNumbers: true}}
            theme='vs-dark'
            value={this.state.code}
            width='800'
          />
        </div>
        <LogsContent logs={this.state.result} />
      </div>
    )
  }

  //private onOpen =() => {
    //console.log('it opened')
    //this.ws.send(JSON.stringify({
      //action: 'register',
      //message: {
        //username: 'test'
      //}
    //}))
  //}

  private editorDidMount = (editor) => {
    editor.focus()
  }

  private onChange = (code) => {
    this.setState({code})
  }

  private changeLanguage = (e) => {
    this.setState({
      language: e.target.value
    })
  }

  private async submitCode() {
    // TODO: do this over websockets
    //this.ws.sendMessage(JSON.stringify({
      //action: ''
    //}))
    this.setState({result: ''})
    await axios.post('http://localhost:3000/submit', {
      language: this.state.language === 'javascript' ? 'js' : 'py',
      script: this.state.code,
      username: 'test',
    })
  }

  private onMessage = (message) => {
    this.setState({
      result: message.data
    })
  }
}

export interface LogsContentProps {
  logs?: string
}

export const LogsContent: React.SFC<LogsContentProps> = (props) => (
  props.logs
  ? (
    <div>
      Ran your code and got: {props.logs}
    </div>
  ) : null
)
