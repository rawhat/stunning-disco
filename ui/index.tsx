import * as React from 'react'
import {Router} from '@reach/router'
import {render} from 'react-dom'

import {Coder} from './component/Coder'
import {Home} from './component/Home'
import {Login} from './component/login'


const App = () => (
  <Router>
    <Home path='/' />
    <Login path='/login' />
    <Coder path='/coder' />
  </Router>
)
render(<App />, document.getElementById('app'))
