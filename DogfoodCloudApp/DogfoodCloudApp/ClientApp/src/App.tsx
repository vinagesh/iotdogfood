import * as React from 'react';
import { Route } from 'react-router';
import Layout from './components/Layout';
import Devices from './components/Devices';

import './custom.css'

export default () => (
    <Layout>
        <Route exact path='/' component={Devices} />
    </Layout>
);
