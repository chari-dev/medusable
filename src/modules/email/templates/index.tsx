import { MedusaError } from "@medusajs/utils";
import { ReactNode } from "react";
import { INVITE_USER, InviteUserEmail, isInviteUserData } from "./invite-user";
import {
  ORDER_PLACED,
  OrderPlacedTemplate,
  isOrderPlacedTemplateData,
} from "./order-placed";

export const EmailTemplates = {
  INVITE_USER,
  ORDER_PLACED,
} as const;

export type EmailTemplateType = keyof typeof EmailTemplates;

export function generateEmailTemplate(
  templateKey: string,
  data: unknown,
): ReactNode {
  switch (templateKey) {
    case EmailTemplates.INVITE_USER:
      if (!isInviteUserData(data)) {
        throw new MedusaError(
          MedusaError.Types.INVALID_DATA,
          `Invalid data for template "${EmailTemplates.INVITE_USER}"`,
        );
      }
      return <InviteUserEmail {...data} />;

    case EmailTemplates.ORDER_PLACED:
      if (!isOrderPlacedTemplateData(data)) {
        throw new MedusaError(
          MedusaError.Types.INVALID_DATA,
          `Invalid data for template "${EmailTemplates.ORDER_PLACED}"`,
        );
      }
      return <OrderPlacedTemplate {...data} />;

    default:
      throw new MedusaError(
        MedusaError.Types.INVALID_DATA,
        `Unknown template key: "${templateKey}"`,
      );
  }
}

export { InviteUserEmail, OrderPlacedTemplate };
