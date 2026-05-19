declare module "nodemailer" {
  type SendMailOptions = {
    from?: string;
    to: string | string[];
    subject: string;
    html?: string;
    text?: string;
    replyTo?: string;
  };

  type TransportOptions = {
    host?: string;
    port?: number;
    secure?: boolean;
    auth?: {
      user?: string;
      pass?: string;
    };
  };

  type SentMessageInfo = {
    messageId?: string;
  };

  export function createTransport(options: TransportOptions): {
    sendMail(options: SendMailOptions): Promise<SentMessageInfo>;
  };
}
