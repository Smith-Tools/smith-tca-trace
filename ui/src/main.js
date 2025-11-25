import { mount } from 'svelte'
import './app.css'
import App from './App.svelte'

// Use sample data for testing
const sampleData = {
  "metadata": {
    "name": "ReadingLibrary TCA Analysis",
    "analyzedAt": "2025-11-25T21:57:00Z"
  },
  "actions": [
    {
      "actionName": "sidebarSelectionChanged",
      "featureName": "ReadingLibrary",
      "duration": 0.000053,
      "timestamp": 13.09,
      "metadata": "ReadingLibrary context"
    },
    {
      "actionName": "selectArticle",
      "featureName": "ReadingLibrary",
      "duration": 0.000044,
      "timestamp": 13.10,
      "metadata": "Article selection"
    },
    {
      "actionName": "reader(.task)",
      "featureName": "ReadingLibrary",
      "duration": 0.001707,
      "timestamp": 15.79,
      "metadata": "Background reader task"
    },
    {
      "actionName": "reader(.cacheLoaded)",
      "featureName": "ReadingLibrary",
      "duration": 0.000046,
      "timestamp": 15.92,
      "metadata": "Cache operation"
    },
    {
      "actionName": "reader(.updateProgress)",
      "featureName": "ReadingLibrary",
      "duration": 0.000047,
      "timestamp": 16.44,
      "metadata": "Progress update"
    },
    {
      "actionName": "articleDomain(.selectionManagement(.setMultiSelection))",
      "featureName": "ReadingLibrary",
      "duration": 0.000100,
      "timestamp": 18.37,
      "metadata": "Multi-selection handling"
    },
    {
      "actionName": "inspector(.setArticle)",
      "featureName": "ReadingLibrary",
      "duration": 0.000088,
      "timestamp": 18.38,
      "metadata": "Article setup"
    },
    {
      "actionName": "inspector(.loadData)",
      "featureName": "ReadingLibrary",
      "duration": 0.806597,
      "timestamp": 18.40,
      "metadata": "Heavy effect for loading inspector data"
    },
    {
      "actionName": "inspector(.notesResponse(.success))",
      "featureName": "ReadingLibrary",
      "duration": 0.000044,
      "timestamp": 19.20,
      "metadata": "Notes loaded successfully"
    },
    {
      "actionName": "inspector(.timelineResponse(.success))",
      "featureName": "ReadingLibrary",
      "duration": 0.000045,
      "timestamp": 19.21,
      "metadata": "Timeline loaded successfully"
    },
    {
      "actionName": "navigationChanged",
      "featureName": "Navigation",
      "duration": 0.000032,
      "timestamp": 20.15,
      "metadata": "Navigation state update"
    },
    {
      "actionName": "setViewState",
      "featureName": "UI",
      "duration": 0.000025,
      "timestamp": 20.16,
      "metadata": "View state mutation"
    }
  ],
  "effects": [
    {
      "name": "reader(.task)",
      "featureName": "ReadingLibrary",
      "duration": 0.001707,
      "timestamp": 15.79
    },
    {
      "name": "inspector(.loadData)",
      "featureName": "ReadingLibrary",
      "duration": 0.806597,
      "timestamp": 18.40
    },
    {
      "name": "notesFetch",
      "featureName": "ReadingLibrary",
      "duration": 0.000834,
      "timestamp": 19.18
    },
    {
      "name": "timelineFetch",
      "featureName": "ReadingLibrary",
      "duration": 0.000645,
      "timestamp": 19.19
    }
  ],
  "metrics": {
    "totalActions": 12,
    "slowActions": 1,
    "avgDuration": 0.083896,
    "maxDuration": 0.806597,
    "features": {
      "ReadingLibrary": {
        "actionCount": 9,
        "slowActions": 1
      },
      "Navigation": {
        "actionCount": 1,
        "slowActions": 0
      },
      "UI": {
        "actionCount": 1,
        "slowActions": 0
      }
    }
  },
  "duration": 25.1,
  "complexityScore": 33
}

const data = window.__TCA_ANALYSIS__ ?? sampleData

const app = mount(App, {
  target: document.getElementById('app'),
  props: { data },
})

export default app
