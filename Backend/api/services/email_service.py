import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from pathlib import Path
import base64
from typing import Optional

class EmailService:
    def __init__(self):
        # Email configuration from environment variables
        self.smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_username = os.getenv("SMTP_USERNAME", "")
        self.smtp_password = os.getenv("SMTP_PASSWORD", "")
        self.from_email = os.getenv("FROM_EMAIL", self.smtp_username)
        
    def _get_logo_base64(self) -> Optional[str]:
        """Get logo as base64 string for embedding in email"""
        try:
            # Try to find logo in assets
            logo_paths = [
                Path(__file__).parent.parent.parent / "Frontend" / "thinky" / "assets" / "logos" / "logo.png",
                Path(__file__).parent.parent.parent / "assets" / "logos" / "logo.png",
            ]
            
            for logo_path in logo_paths:
                if logo_path.exists():
                    with open(logo_path, 'rb') as f:
                        logo_data = f.read()
                        return base64.b64encode(logo_data).decode('utf-8')
            return None
        except Exception as e:
            print(f"[WARNING] Could not load logo: {e}")
            return None
        
    def send_password_reset_code(self, to_email: str, code: str) -> bool:
        """
        Send password reset code via email with HTML formatting.
        Returns True if successful, False otherwise.
        """
        if not self.smtp_username or not self.smtp_password:
            print("[WARNING] SMTP credentials not configured. Email sending disabled.")
            print(f"[INFO] Would send code {code} to {to_email}")
            return False
        
        try:
            # Create message
            msg = MIMEMultipart('related')
            msg['From'] = self.from_email
            msg['To'] = to_email
            msg['Subject'] = "🔐 Thinky - Password Reset Code"
            
            # Get logo
            logo_base64 = self._get_logo_base64()
            logo_html = ""
            if logo_base64:
                logo_html = f'<img src="data:image/png;base64,{logo_base64}" alt="Thinky Logo" style="max-width: 120px; height: auto; margin-bottom: 20px;">'
            
            # HTML email body
            html_body = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset - Thinky</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F5F6FA;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #F5F6FA; padding: 40px 20px;">
        <tr>
            <td align="center">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="max-width: 600px; background-color: #FFFFFF; border-radius: 16px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08); overflow: hidden;">
                    <!-- Header with gradient -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #8E97FD 0%, #9AA2FD 100%); padding: 40px 30px; text-align: center;">
                            {logo_html}
                            <h1 style="margin: 0; color: #FFFFFF; font-size: 28px; font-weight: 700; letter-spacing: -0.5px;">Password Reset</h1>
                        </td>
                    </tr>
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="margin: 0 0 20px 0; color: #222222; font-size: 16px; line-height: 1.6;">
                                Hello!
                            </p>
                            <p style="margin: 0 0 30px 0; color: #60646D; font-size: 15px; line-height: 1.6;">
                                You requested to reset your password for your Thinky account. Use the code below to complete the process.
                            </p>
                            
                            <!-- Code Box -->
                            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 30px 0;">
                                <tr>
                                    <td align="center" style="padding: 30px; background: linear-gradient(135deg, #8E97FD 0%, #9AA2FD 100%); border-radius: 12px;">
                                        <div style="font-size: 42px; font-weight: 700; color: #FFFFFF; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                                            {code}
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 20px 0 0 0; color: #8A8A8F; font-size: 13px; line-height: 1.5; text-align: center;">
                                ⏱️ This code will expire in <strong>10 minutes</strong>
                            </p>
                            
                            <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #E6E7EB;">
                                <p style="margin: 0 0 10px 0; color: #8A8A8F; font-size: 13px; line-height: 1.5;">
                                    If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.
                                </p>
                            </div>
                        </td>
                    </tr>
                    <!-- Footer -->
                    <tr>
                        <td style="padding: 30px; background-color: #F2F3F7; text-align: center; border-top: 1px solid #E6E7EB;">
                            <p style="margin: 0; color: #8A8A8F; font-size: 12px; line-height: 1.5;">
                                Best regards,<br>
                                <strong style="color: #8E97FD;">The Thinky Team</strong>
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
"""
            
            # Plain text fallback
            text_body = f"""
Hello!

You requested to reset your password for your Thinky account.

Your password reset code is: {code}

This code will expire in 10 minutes.

If you didn't request this, please ignore this email.

Best regards,
The Thinky Team
"""
            
            # Attach both HTML and plain text
            msg_alternative = MIMEMultipart('alternative')
            msg_alternative.attach(MIMEText(text_body, 'plain'))
            msg_alternative.attach(MIMEText(html_body, 'html'))
            msg.attach(msg_alternative)
            
            # Send email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_username, self.smtp_password)
                server.send_message(msg)
            
            print(f"[OK] Password reset code sent to {to_email}")
            return True
            
        except Exception as e:
            print(f"[ERROR] Failed to send email to {to_email}: {e}")
            import traceback
            traceback.print_exc()
            return False

# Singleton instance
email_service = EmailService()

