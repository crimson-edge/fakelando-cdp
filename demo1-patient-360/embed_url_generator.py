#!/usr/bin/env python3
"""
Fakelando Health - Looker Studio Embedded Dashboard Generator
===============================================================
Generates signed embed URLs for patient-specific dashboards.
"""

import os
import json
import hmac
import hashlib
import base64
import time
from datetime import datetime

# Configuration - Replace with actual values
LOOKER_HOST = os.getenv("LOOKER_HOST", "https://looker.fakelandohealth.com")
LOOKER_EMBED_SECRET = os.getenv("LOOKER_EMBED_SECRET")  # Base64 encoded secret from Looker Admin > Embed
LOOKER_MODEL = "fakelando_health"
PATIENT_360_DASHBOARD_ID = "patient_360"

def create_signed_embed_url(
    target_url: str,
    external_user_id: str,
    first_name: str,
    last_name: str,
    permissions: list = None,
    models: list = None,
    group_ids: list = None,
    session_length: int = 300,  # 5 minutes
    force_logout_login: bool = True
) -> str:
    """
    Create a Looker signed embed URL for patient-specific dashboard access.
    
    Args:
        target_url: Full Looker URL to embed (e.g., /dashboards/patient_360?patient_mrn=PAT-000164)
        external_user_id: Unique identifier for the user (e.g., "agent_001", "provider_123")
        first_name: User's first name
        last_name: User's last name
        permissions: List of Looker permissions
        models: List of LookML models user can access
        group_ids: Looker group IDs for access control
        session_length: Session duration in seconds
        force_logout_login: Force logout before login
    
    Returns:
        Signed embed URL ready for iframe embedding
    """
    
    if not LOOKER_EMBED_SECRET:
        raise ValueError("LOOKER_EMBED_SECRET environment variable not set")
    
    payload = {
        "target_url": target_url,
        "session_length": session_length,
        "force_logout_login": force_logout_login,
        "user": {
            "external_user_id": external_user_id,
            "first_name": first_name,
            "last_name": last_name,
        }
    }
    
    if permissions:
        payload["permissions"] = permissions
    if models:
        payload["models"] = models
    if group_ids:
        payload["group_ids"] = group_ids
    
    # Create payload JSON (compact, no spaces)
    payload_json = json.dumps(payload, separators=(',', ':'))
    
    # Decode secret and sign
    secret_bytes = base64.b64decode(LOOKER_EMBED_SECRET)
    signature = hmac.new(secret_bytes, payload_json.encode(), hashlib.sha256).digest()
    
    # Combine payload + signature and base64 encode
    encoded = base64.urlsafe_b64encode(payload_json.encode() + b'.' + signature).decode()
    
    return f"{LOOKER_HOST}/login/embed/{encoded}"


def generate_patient_dashboard_url(
    patient_mrn: str,
    user_id: str,
    user_name: str,
    user_role: str = "clinician"  # clinician, admin, billing, patient
) -> dict:
    """Generate embed URL for a specific patient dashboard."""
    
    # Parse name
    name_parts = user_name.split(" ", 1)
    first_name = name_parts[0]
    last_name = name_parts[1] if len(name_parts) > 1 else ""
    
    # Role-based permissions
    role_permissions = {
        "clinician": [
            "see_user_dashboards", "see_lookml_dashboards", "explore",
            "download_with_limit", "send_to_s3", "send_to_sftp"
        ],
        "admin": [
            "see_user_dashboards", "see_lookml_dashboards", "explore",
            "manage_models", "manage_data", "admin_users", "admin_scheduled_jobs",
            "download_without_limit", "send_to_s3", "send_to_sftp"
        ],
        "billing": [
            "see_user_dashboards", "see_lookml_dashboards", "explore",
            "download_with_limit", "see_sql"
        ],
        "patient": [
            "see_user_dashboards", "see_lookml_dashboards"
        ]
    }
    
    # Role-based models access
    role_models = {
        "clinician": ["fakelando_health"],
        "admin": ["fakelando_health", "fakelando_admin"],
        "billing": ["fakelando_health"],
        "patient": ["fakelando_health_patient_view"]  # Restricted model
    }
    
    # Build target URL with patient filter
    target_url = f"/dashboards/{PATIENT_360_DASHBOARD_ID}?patient_mrn={patient_mrn}"
    
    embed_url = create_signed_embed_url(
        target_url=target_url,
        external_user_id=user_id,
        first_name=first_name,
        last_name=last_name,
        permissions=role_permissions.get(user_role, role_permissions["clinician"]),
        models=role_models.get(user_role, role_models["clinician"]),
        session_length=1800  # 30 minutes for clinicians
    )
    
    return {
        "embed_url": embed_url,
        "patient_mrn": patient_mrn,
        "user_id": user_id,
        "user_role": user_role,
        "expires_in_seconds": 1800,
        "generated_at": datetime.utcnow().isoformat() + "Z"
    }


def generate_clinician_call_center_url(
    agent_id: str,
    agent_name: str,
    patient_mrn: str
) -> dict:
    """Generate URL for call center agent viewing patient during call."""
    return generate_patient_dashboard_url(
        patient_mrn=patient_mrn,
        user_id=f"agent_{agent_id}",
        user_name=agent_name,
        user_role="clinician"
    )


def generate_provider_portal_url(
    provider_npi: str,
    provider_name: str,
    patient_mrn: str
) -> dict:
    """Generate URL for provider portal access."""
    return generate_patient_dashboard_url(
        patient_mrn=patient_mrn,
        user_id=f"provider_{provider_npi}",
        user_name=provider_name,
        user_role="clinician"
    )


def generate_billing_portal_url(
    billing_user_id: str,
    billing_user_name: str,
    patient_mrn: str
) -> dict:
    """Generate URL for billing team access."""
    return generate_patient_dashboard_url(
        patient_mrn=patient_mrn,
        user_id=f"billing_{billing_user_id}",
        user_name=billing_user_name,
        user_role="billing"
    )


def generate_patient_portal_url(
    patient_mrn: str,
    patient_name: str
) -> dict:
    """Generate URL for patient self-service portal."""
    return generate_patient_dashboard_url(
        patient_mrn=patient_mrn,
        user_id=f"patient_{patient_mrn}",
        user_name=patient_name,
        user_role="patient"
    )


if __name__ == "__main__":
    # Demo usage
    print("=" * 60)
    print("FAKELANDO HEALTH - LOOKER STUDIO EMBED URL GENERATOR")
    print("=" * 60)
    
    # Example: Call center agent
    result = generate_clinician_call_center_url(
        agent_id="001",
        agent_name="Sarah Clinician",
        patient_mrn="PAT-000164"
    )
    
    print("\n📞 Call Center Agent Dashboard:")
    print(f"   Agent: Sarah Clinician (agent_001)")
    print(f"   Patient: PAT-000164")
    print(f"   Embed URL: {result['embed_url'][:80]}...")
    print(f"   Expires: {result['expires_in_seconds']} seconds")
    
    # Example: Provider portal
    result = generate_provider_portal_url(
        provider_npi="1234567890",
        provider_name="Dr. Michael Chen",
        patient_mrn="PAT-000164"
    )
    
    print("\n🏥 Provider Portal:")
    print(f"   Provider: Dr. Michael Chen (NPI: 1234567890)")
    print(f"   Patient: PAT-000164")
    print(f"   Embed URL: {result['embed_url'][:80]}...")
    
    # Example: Patient portal
    result = generate_patient_portal_url(
        patient_mrn="PAT-000164",
        patient_name="John Doe"
    )
    
    print("\n👤 Patient Portal:")
    print(f"   Patient: John Doe (PAT-000164)")
    print(f"   Embed URL: {result['embed_url'][:80]}...")
    
    print("\n" + "=" * 60)
    print("SETUP INSTRUCTIONS:")
    print("1. Enable Signed Embedding in Looker Admin > Embed")
    print("2. Copy the Embed Secret and set LOOKER_EMBED_SECRET env var")
    print("3. Create patient_360 dashboard in Looker Studio")
    print("4. Add row-level security filter: patient_mrn = @patient_mrn")
    print("5. Set LOOKER_HOST to your Looker instance URL")
    print("=" * 60)