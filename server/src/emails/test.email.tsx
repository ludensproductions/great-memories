import { Link, Row, Text } from '@react-email/components';
import * as React from 'react';
import GreatMemoriesLayout from 'src/emails/components/great-memories.layout';
import { TestEmailProps } from 'src/repositories/email.repository';

export const TestEmail = ({ baseUrl, displayName }: TestEmailProps) => (
  <GreatMemoriesLayout preview="This is a test email from Great Memories.">
    <Text className="m-0">
      Hey <strong>{displayName}</strong>!
    </Text>

    <Text>This is a test email from your Great Memories instance!</Text>

    <Row>
      <Link href={baseUrl}>{baseUrl}</Link>
    </Row>
  </GreatMemoriesLayout>
);

TestEmail.PreviewProps = {
  baseUrl: 'https://demo.immich.app',
  displayName: 'Alan Turing',
} as TestEmailProps;

export default TestEmail;
