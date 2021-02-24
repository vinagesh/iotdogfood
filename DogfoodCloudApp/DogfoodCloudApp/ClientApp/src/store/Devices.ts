import { Action, Reducer } from 'redux';
import { AppThunkAction } from '.';

// -----------------
// STATE - This defines the type of data maintained in the Redux store.

export interface DevicesState {
    isLoading: boolean;
    startDateIndex?: number;
    iotHubName: string
    devices: Device[];
}

export interface Device {
    id: string;
    status: string;
    connectionState: string
}

// -----------------
// ACTIONS - These are serializable (hence replayable) descriptions of state transitions.
// They do not themselves have any side-effects; they just describe something that is going to happen.

interface RequestDevicesAction {
    type: 'REQUEST_DEVICES';
    startDateIndex: number;
}

interface ReceiveDevicesAction {
    type: 'RECEIVE_DEVICES';
    startDateIndex: number;
    devices: Device[];
    iotHubName: string;
}

// Declare a 'discriminated union' type. This guarantees that all references to 'type' properties contain one of the
// declared type strings (and not any other arbitrary string).
type KnownAction = RequestDevicesAction | ReceiveDevicesAction;

// ----------------
// ACTION CREATORS - These are functions exposed to UI components that will trigger a state transition.
// They don't directly mutate state, but they can have external side-effects (such as loading data).

export const actionCreators = {
    requestDevices: (startDateIndex: number): AppThunkAction<KnownAction> => async (dispatch, getState) => {
        // Only load data if it's something we don't already have (and are not already loading)
        const appState = getState();
        const requestOptions = {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        };
        if (appState && appState.devices && startDateIndex !== appState.devices.startDateIndex) {
            dispatch({ type: 'REQUEST_DEVICES', startDateIndex: startDateIndex });
            var devices: Device[] = await (await fetch('devices', requestOptions)).json();
            var e2 = await fetch('iotHubName', requestOptions);
            var iothubName = await e2.text();
            dispatch({ type: 'RECEIVE_DEVICES', startDateIndex: startDateIndex, devices: devices, iotHubName: iothubName });            
        }
    }
};

// ----------------
// REDUCER - For a given state and action, returns the new state. To support time travel, this must not mutate the old state.

const unloadedState: DevicesState = { devices: [], isLoading: false, iotHubName: '' };

export const reducer: Reducer<DevicesState> = (state: DevicesState | undefined, incomingAction: Action): DevicesState => {
    if (state === undefined) {
        return unloadedState;
    }

    const action = incomingAction as KnownAction;
    switch (action.type) {
        case 'REQUEST_DEVICES':
            return {
                startDateIndex: action.startDateIndex,
                devices: state.devices,
                isLoading: true,
                iotHubName: state.iotHubName
            };
        case 'RECEIVE_DEVICES':
            // Only accept the incoming data if it matches the most recent request. This ensures we correctly
            // handle out-of-order responses.
            if (action.startDateIndex === state.startDateIndex) {
                return {
                    startDateIndex: action.startDateIndex,
                    devices: action.devices,
                    isLoading: false,
                    iotHubName: action.iotHubName
                };
            }
            break;
    }

    return state;
};
