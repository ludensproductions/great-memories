import { Link, Section, Text } from '@react-email/components';
import * as React from 'react';
import { GreatMemoriesButton } from 'src/emails/components/button.component';
import FutoLayout from 'src/emails/components/futo.layout';

/**
 * Template to be used for FUTOPay project
 * Variable is {{LICENSEKEY}}
 * */
export const LicenseEmail = () => (
  <FutoLayout preview="Your Great Memories Server License">
    <Text>Thank you for supporting Great Memories and open-source software</Text>

    <Text>
      Your <strong>Great Memories</strong> key is
    </Text>

    <Section className="my-2 bg-gray-200 rounded-2xl text-center p-4">
      <Text className="m-0 text-monospace font-bold text-great-memories-primary">{'{{LICENSEKEY}}'}</Text>
    </Section>

    <Text>
      To activate your instance, you can click the following button or copy and paste the link below to your browser.
    </Text>

    <Section className="flex justify-center my-6">
      <GreatMemoriesButton
        href={`https://my.immich.app/link?target=activate_license&licenseKey={{LICENSEKEY}}&activationKey={{ACTIVATIONKEY}}`}
      >
        Activate
      </GreatMemoriesButton>
    </Section>

    <Text className="text-center">
      <Link
        className="text-great-memories-primary text-sm"
        // style={{ marginTop: '50px', color: 'rgb(66, 80, 175)', fontSize: '0.9rem' }}
        href={`https://my.immich.app/link?target=activate_license&licenseKey={{LICENSEKEY}}&activationKey={{ACTIVATIONKEY}}`}
      >
        https://my.immich.app/link?target=activate_license&licenseKey={'{{LICENSEKEY}}'}&activationKey=
        {'{{ACTIVATIONKEY}}'}
      </Link>
    </Text>
  </FutoLayout>
);

LicenseEmail.PreviewProps = {};

export default LicenseEmail;
