import { Link, Section, Text } from '@react-email/components';
import * as React from 'react';
import { GreatMemoriesButton } from 'src/emails/components/button.component';
import GreatMemoriesLayout from 'src/emails/components/great-memories.layout';
import { WelcomeEmailProps } from 'src/repositories/email.repository';
import { replaceTemplateTags } from 'src/utils/replace-template-tags';

export const WelcomeEmail = ({ baseUrl, displayName, username, password, customTemplate }: WelcomeEmailProps) => {
  const usableTemplateVariables = {
    displayName,
    username,
    password,
    baseUrl,
  };

  const emailContent = customTemplate ? (
    replaceTemplateTags(customTemplate, usableTemplateVariables)
  ) : (
    <>
      <Text className="m-0">
        Hey <strong>{displayName}</strong>!
      </Text>

      <Text>A new account has been created for you.</Text>

      <Text>
        <strong>Username</strong>: {username}
        {password && (
          <>
            <br />
            <strong>Password</strong>: {password}
          </>
        )}
      </Text>
    </>
  );

  return (
    <GreatMemoriesLayout
      preview={customTemplate ? emailContent.toString() : 'You have been invited to a new Great Memories instance.'}
    >
      {customTemplate && (
        <Text className="m-0">
          <div dangerouslySetInnerHTML={{ __html: emailContent }}></div>
        </Text>
      )}

      {!customTemplate && emailContent}

      <Section className="flex justify-center my-6">
        <GreatMemoriesButton href={`${baseUrl}/auth/login`}>Login</GreatMemoriesButton>
      </Section>

      <Text className="text-xs">
        If you cannot click the button use the link below to proceed with first login.
        <br />
        <Link href={baseUrl}>{baseUrl}</Link>
      </Text>
    </GreatMemoriesLayout>
  );
};

WelcomeEmail.PreviewProps = {
  baseUrl: 'https://demo.immich.app/auth/login',
  displayName: 'Alan Turing',
  username: 'alanturing@immich.app',
  password: 'mysuperpassword',
} as WelcomeEmailProps;

export default WelcomeEmail;
