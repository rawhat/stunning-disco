import * as React from 'react'
import {Link} from '@reach/router'
import {RouterProps} from '@reach/router'


export const Home: React.SFC<RouterProps> = () => (
  <>
    <span>Hello, world!</span>
    <Link to='/login'>Login</Link>
    <Link to='/coder'>Code!</Link>
  </>
)
