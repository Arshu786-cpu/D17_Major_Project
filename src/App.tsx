import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './hooks/useAuth'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AppLayout } from './components/AppLayout'
import { AuthPage } from './pages/AuthPage'
import { Dashboard } from './pages/Dashboard'
import { Placeholder } from './pages/Placeholder'

function placeholder(title: string, description: string) {
  return <Placeholder title={title} description={description} />
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/auth" element={<AuthPage />} />

          <Route
            path="/"
            element={
              <ProtectedRoute>
                <AppLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="assistant" element={placeholder('AI Assistant', 'Chat with the Main Agent. It will route your question to the right specialist agent and return a grounded answer with sources.')} />
            <Route path="agents" element={placeholder('Agent Center', 'Visualize the Main Agent and five specialist agents, their capabilities, tools, and recent execution history.')} />
            <Route path="knowledge" element={placeholder('Knowledge', 'Browse and manage your organization\'s knowledge base.')} />
            <Route path="documents" element={placeholder('Documents', 'Upload and manage enterprise documents — PDF, DOCX, TXT, and Markdown.')} />
            <Route path="search" element={placeholder('Semantic Search', 'Search your knowledge base by meaning, not just keywords.')} />
            <Route path="github" element={placeholder('GitHub Intelligence', 'Connect repositories and ask questions about your source code.')} />
            <Route path="reports" element={placeholder('Reports', 'AI-generated reports from your knowledge, documents, and code.')} />
            <Route path="analytics" element={placeholder('Analytics', 'Usage insights, search trends, and AI activity across your organization.')} />
            <Route path="activity" element={placeholder('Activity', 'Audit trail of AI executions and user actions.')} />
            <Route path="settings" element={placeholder('Settings', 'Manage your profile and preferences.')} />
            <Route path="admin" element={placeholder('Admin', 'Manage users, roles, and organization settings.')} />
          </Route>

          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
