import * as React from 'react';
import { connect } from 'react-redux';
import { RouteComponentProps } from 'react-router';
import { ApplicationState } from '../store';
import * as DevicesStore from '../store/Devices';

// At runtime, Redux will merge together...
type DevicesProps =
    DevicesStore.DevicesState // ... state we've requested from the Redux store
    & typeof DevicesStore.actionCreators // ... plus action creators we've requested
    & RouteComponentProps<{ startDateIndex: string }>; // ... plus incoming routing parameters

class FetchDevices extends React.PureComponent<DevicesProps> {
  // This method is called when the component is first added to the document
  public componentDidMount() {
    this.ensureDataFetched();
  }

  // This method is called when the route parameters change
  public componentDidUpdate() {
    this.ensureDataFetched();
  }

  public render() {
    return (
        <React.Fragment>
            <h1 id="tabelLabel">{this.props.iotHubName} devices</h1>
            {this.renderDevicesTable()}
      </React.Fragment>
    );
  }

  private ensureDataFetched() {
    const startDateIndex = parseInt(this.props.match.params.startDateIndex, 10) || 0;
    this.props.requestDevices(startDateIndex);
  }

  private renderDevicesTable() {
    return (
      <table className='table table-striped' aria-labelledby="tabelLabel">
        <thead>
          <tr>
            <th>Id</th>
            <th>Status</th>
            <th>ConnectionState</th>
          </tr>
        </thead>
            <tbody>
                {this.props.devices.map((device: DevicesStore.Device) =>
                <tr key={device.id}>
                  <td>{device.id}</td>
                  <td>{device.status}</td>
                  <td>{device.connectionState}</td>
                </tr>
          )}
        </tbody>
      </table>
    );
  }
}

export default connect(
    (state: ApplicationState) => state.devices, // Selects which state properties are merged into the component's props
  DevicesStore.actionCreators // Selects which action creators are merged into the component's props
)(FetchDevices as any);
