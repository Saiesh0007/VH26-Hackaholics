from abc import ABC, abstractmethod
from typing import Dict, Any
from models.domain_policy import DomainPolicy

class AIProvider(ABC):
    """
    Abstract AI Provider interface.
    Allows seamlessly plugging in Gemini, Grok, OpenAI, or local models without modifying
    the rest of the AdaptQ control plane.
    """
    @abstractmethod
    async def generate_domain_policy(self, user_description: str) -> DomainPolicy:
        """Generate a structured DomainPolicy from natural language description."""
        pass

    @abstractmethod
    async def chat_copilot(self, query: str, context: Dict[str, Any]) -> Dict[str, str]:
        """Provide structured answers to operator questions regarding active pipeline state."""
        pass

    @abstractmethod
    async def explain_decision(self, event_data: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Explain the routing/strategy decision for a specific event."""
        pass

    @abstractmethod
    async def what_if_analysis(self, scenario_params: Dict[str, Any], simulation_results: Dict[str, Any]) -> Dict[str, str]:
        """Analyze what-if simulation results and provide strategic recommendations."""
        pass
