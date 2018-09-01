import * as React from 'react'
import {Link} from '@reach/router'
import {Router} from '@reach/router'
import {render} from 'react-dom'

import {Home} from './component/Home'
import {Login} from './component/login'


const App = () => (
  <Router>
    <Home path='/' />
    <Login path='/login' />
  </Router>
)
render(<App />, document.getElementById('app'))
