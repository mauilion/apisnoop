import { createAsyncResourceBundle, createSelector } from 'redux-bundler'

const bundle = createAsyncResourceBundle({
  name: 'endpoints',
  getPromise: ({ client, store }) => {
    const currentReleaseName = store.selectCurrentReleaseName()
    return fetchEndpointsByReleaseName(client, currentReleaseName)
  }
})

bundle.reactEndpointsFetch = createSelector(
  'selectEndpointsShouldUpdate',
  (shouldUpdate, currentReleaseId) => {
    if (!shouldUpdate) return
    return { actionCreator: 'doFetchEndpoints' }
  }
)


export default bundle

function fetchEndpointsByReleaseName (client, releaseName) {
  return client.service('endpoints').find({
    query: {
      release: releaseName
    }
  })
}
